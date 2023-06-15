import { ethers } from "ethers"
import { useEffect, useRef, useState } from "react"
import abi from "../../truffle/build/contracts/Pool.json"
import "./styles.css"

function App() {
    const [provier, setProvier] = useState()
    const [signer, setSigner] = useState()
    const [accounts, setAccounts] = useState([])
    const [contract, setContract] = useState()
    const [swpup, setSwpup] = useState()
    const [weth, setWeth] = useState()
    const amountSwpup = useRef(NaN)
    const amountMinSwpup = useRef(NaN)
    const amountWeth = useRef(NaN)
    const amountMinWeth = useRef(NaN)
    const swpupForSwap = useRef(NaN)
    const wethForSwap = useRef(NaN)
    const contractAddress = "0xb2a248e442012135af1C75C371DA796f2cA4922b"//"0xF1C647b414C8B45FC64cd544C9f681aAE676948E"//"0xbde69812Bf803bc3b0c38785522dD96C666E208D"
    const swpupAddress = "0x49686479d16105c278a766f3Abe24d3D50300a71"
    const wethAddress = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
    const minAbi = [
        {
            inputs: [
                {
                    internalType: "address",
                    name: "to",
                    type: "address"
                },
                {
                    internalType: "uint256",
                    name: "amount",
                    type: "uint256"
                }
            ],
            name: "transfer",
            outputs: [
                {
                    internalType: "bool",
                    name: "",
                    type: "bool"
                }
            ],
            stateMutability: "nonpayable",
            type: "function"
        }
    ]

    useEffect(() => {
        ;(async () => {
            const provider = new ethers.providers.Web3Provider(window.ethereum)
            const accounts = await provider.send("eth_requestAccounts", [])
            const signer = provider.getSigner()
            const contract = new ethers.Contract(contractAddress, abi, signer)
            const swpup = new ethers.Contract(swpupAddress, minAbi, signer)
            const weth = new ethers.Contract(wethAddress, minAbi, signer)
            setProvier(provider)
            setAccounts(accounts)
            setSigner(signer)
            setContract(contract)
            setSwpup(swpup)
            setWeth(weth)
        })()
        window.ethereum.on("accountsChanged", (accounts) => {
            console.log(accounts)
            setAccounts(accounts)
        })
    }, [])

    const addLiquidity = async (e) => {
        e.preventDefault()
        try {
            const txSwpupTransfer = await swpup["transfer(address,uint256)"](
                contractAddress,
                ethers.utils.parseEther(amountSwpup.current)
            )
            console.log(txSwpupTransfer)
            const txWethTransfer = await weth["transfer(address,uint256)"](
                contractAddress,
                ethers.utils.parseEther(amountWeth.current)
            )
            console.log(txWethTransfer)
            const txLiquidity = await contract[
                "addLiquidity(uint256,uint256,uint256,uint256)"
            ](
                ethers.utils.parseEther(amountSwpup.current),
                1,
                ethers.utils.parseEther(amountWeth.current),
                1
            )
            console.log(txLiquidity)
        } catch (err) {
            console.error(err)
        }
    }

    const removeLiquidity = async () => {
        try {
            const tx = await contract["removeLiquidity()"]()
            console.log(tx)
        } catch (err) {
            console.error(err)
        }
    }

    const swapSwpup = async (e) => {
        e.preventDefault()
        try {
            const txSwpupTransfer = await swpup["transfer(address,uint256)"](
                contractAddress,
                ethers.utils.parseEther(swpupForSwap.current)
            )
            console.log(txSwpupTransfer)
            const tx = await contract[
                "swapSwpupForWeth(uint256)"
            ](
                ethers.utils.parseEther(swpupForSwap.current)
            )
            console.log(tx)
        } catch (err) {
            console.error(err)
        }
    }

    const swapWeth = async (e) => {
        e.preventDefault()
        try {
            const txWethTransfer = await weth["transfer(address,uint256)"](
                contractAddress,
                ethers.utils.parseEther(wethForSwap.current)
            )
            console.log(txWethTransfer)
            const tx = await contract["swapWethForSwpup(uint256)"](
                ethers.utils.parseEther(wethForSwap.current)
            )
            console.log(tx)
        } catch (err) {
            console.error(err)
        }
    }

    return (
        <div id="App">
            <section className="liquidity container">
                <h1>Liquidity</h1>
                <form onSubmit={addLiquidity}>
                    <input
                        className="inp-data"
                        type="number"
                        step="any"
                        placeholder="Enter weth amount"
                        onChange={(e) => {
                            amountWeth.current = e.target.value
                        }}
                    />
                    {/* <input
                        className="inp-data"
                        type="number"
                        placeholder="Enter min. weth amount"
                        onChange={(e) => {
                            amountMinWeth.current = e.target.valueAsNumber
                        }}
                    /> */}
                    <input
                        className="inp-data"
                        type="number"
                        placeholder="Enter swpup amount"
                        step="any"
                        onChange={(e) => {
                            amountSwpup.current = e.target.value
                        }}
                    />
                    {/* <input
                        className="inp-data"
                        type="number"
                        placeholder="Enter min swpup amount"
                        onChange={(e) => {
                            amountMinSwpup.current = e.target.valueAsNumber
                        }}
                    /> */}
                    <input type="submit" value="ADD LIQUIDITY" />
                </form>
                <button onClick={removeLiquidity}>REMOVE LIQUIDITY</button>
            </section>
            <section className="swap container">
                <h1>Swap</h1>
                <div className="swap-forms">
                    <form onSubmit={swapSwpup}>
                        <input
                            type="number"
                            step="any"
                            className="inp-data"
                            placeholder="enter swpup amount to swap"
                            onChange={(e) => {
                                swpupForSwap.current = e.target.value
                            }}
                        />
                        <input type="submit" value="SWAP TO WETH" />
                    </form>
                    <form onSubmit={swapWeth}>
                        <input
                            type="number"
                            step="any"
                            className="inp-data"
                            placeholder="enter weth amount To swap"
                            onChange={(e) => {
                                wethForSwap.current = e.target.value
                            }}
                        />
                        <input type="submit" value="SWAP TO SWPUP" />
                    </form>
                </div>
            </section>
        </div>
    )
}

export default App
